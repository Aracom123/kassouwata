package com.techinnov.kassouwata_back.controllers;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.rest.webmvc.ResourceNotFoundException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RestController;

import com.techinnov.kassouwata_back.entitites.Boutique;
import com.techinnov.kassouwata_back.entitites.Commande;
import com.techinnov.kassouwata_back.entitites.ProduitCommande;
import com.techinnov.kassouwata_back.entitites.Sms;
import com.techinnov.kassouwata_back.repositories.CommandeRepository;
import com.techinnov.kassouwata_back.repositories.ProduitRepository;
import com.techinnov.kassouwata_back.services.SmsService;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosCommandes")
public class CommandeController {
	@Autowired
	private CommandeRepository commandeRepository;

	@Autowired
	private ProduitRepository produitRepository;

	@Autowired
	private SmsService smsService;

	
	//Get All Commandes
	@GetMapping("/list")
	public List<Commande> getAllCommandes(){
		return commandeRepository.findAllOrderByCreatedAtDesc();
	}

	//Get Commandes by Client
	@GetMapping("/byClient/{userId}")
	public List<Commande> getCommandesByClient(@PathVariable UUID userId){
		return commandeRepository.findByClient_IdUser(userId);
	}

	//Get Commandes by Boutique (pour le vendeur)
	@GetMapping("/byBoutique/{idBoutique}")
	public List<Commande> getCommandesByBoutique(@PathVariable Long idBoutique){
		return commandeRepository.findByBoutiqueId(idBoutique);
	}

	//Get Commande By Id
	@GetMapping("/{id}")
	public ResponseEntity<Commande> getCommandeById(@PathVariable Long id){
		Commande commande = commandeRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Commande not exit with id:" +id));
		 return ResponseEntity.ok(commande);
	
	}
		
	/**
	 * Créer une ou plusieurs commandes à partir du panier du client.
	 *
	 * Règles métier basées sur le champ {@code typeVente} :
	 * - POSTPAYE : une seule commande est créée avec tous les produits du panier.
	 * - PREPAYE  : le panier est éclaté en autant de commandes qu'il y a de produits.
	 *              Chaque commande ne contiendra qu'une seule ligne (un seul produit).
	 *              Le nombre de tranches de paiement est défini sur le produit concerné
	 *              (cf. Produit.nombreTranches).
	 *
	 * @param commande La commande reçue depuis le client (avec toutes les lignes du panier).
	 * @return La liste des commandes créées (1 si POSTPAYE, N si PREPAYE).
	 */
	@PostMapping("/save")
	public ResponseEntity<?> addCommande(@RequestBody Commande commande) {
		// Valider le typeVente
		String typeVente = commande.getTypeVente();
		if (typeVente == null || typeVente.isBlank()) {
			return ResponseEntity.badRequest()
					.body("Le champ 'typeVente' est obligatoire (PREPAYE ou POSTPAYE).");
		}
		typeVente = typeVente.toUpperCase().trim();
		if (!typeVente.equals("PREPAYE") && !typeVente.equals("POSTPAYE")) {
			return ResponseEntity.badRequest()
					.body("Valeur de 'typeVente' invalide. Valeurs acceptées : PREPAYE, POSTPAYE.");
		}

		if (typeVente.equals("POSTPAYE")) {
			// Mode POSTPAYE : une seule commande, plusieurs produits autorisés
			commande.setTypeVente("POSTPAYE");
			// Rattacher chaque ligne à la commande et résoudre les références produit
			if (commande.getLignes() != null) {
				for (ProduitCommande ligne : commande.getLignes()) {
					ligne.setCommande(commande);
					resolveProduit(ligne);
				}
			}
			Commande saved = commandeRepository.save(commande);

			// Notifier tous les vendeurs concernés par la commande
			notifierVendeurs(saved);

			return ResponseEntity.ok(List.of(saved));

		} else {
			// Mode PREPAYE : éclatement — une commande par produit
			List<ProduitCommande> lignes = commande.getLignes();
			if (lignes == null || lignes.isEmpty()) {
				return ResponseEntity.badRequest()
						.body("La commande prépayée doit contenir au moins un produit.");
			}

			List<Commande> commandesCrees = new ArrayList<>();
			for (ProduitCommande ligne : lignes) {
				// Résoudre la référence produit avant tout accès
				resolveProduit(ligne);

				Commande commandeUnitaire = new Commande();
				commandeUnitaire.setDateCommande(commande.getDateCommande());
				commandeUnitaire.setStatut("EN_ATTENTE");
				commandeUnitaire.setTypeVente("PREPAYE");
				commandeUnitaire.setMoyenPaiement(commande.getMoyenPaiement());
				commandeUnitaire.setAdresseLivraison(commande.getAdresseLivraison());
				commandeUnitaire.setClient(commande.getClient());

				// Calculer le montant total de cette commande unitaire
				double montant = ligne.getPrixUnitaire() * ligne.getQuantite();
				commandeUnitaire.setMontantTotal(montant);

				// Rattacher la ligne à cette commande unitaire
				ligne.setCommande(commandeUnitaire);
				commandeUnitaire.setLignes(new ArrayList<>(List.of(ligne)));

				Commande saved = commandeRepository.save(commandeUnitaire);
				commandesCrees.add(saved);

				// Notifier le vendeur de cette commande unitaire
				notifierVendeurs(saved);
			}
			return ResponseEntity.ok(commandesCrees);
		}
	}

	/**
	 * Envoie un SMS de notification à chaque vendeur concerné par une commande.
	 * Un vendeur peut avoir plusieurs produits dans la même commande : il ne reçoit
	 * qu'un seul SMS par commande (déduplication par numéro de téléphone).
	 */
	private void notifierVendeurs(Commande commande) {
		try {
			Set<String> telephones = new HashSet<>();
			if (commande.getLignes() == null) return;

			for (ProduitCommande ligne : commande.getLignes()) {
				if (ligne.getProduit() == null) continue;
				Boutique boutique = ligne.getProduit().getBoutique();
				if (boutique == null || boutique.getVendeur() == null) continue;
				String telephone = boutique.getVendeur().getTelephone();
				if (telephone == null || telephone.isBlank()) continue;
				if (!telephones.add(telephone)) continue; // déjà notifié

				String nomBoutique = boutique.getLibelle() != null ? boutique.getLibelle() : "votre boutique";
				String message = "Vous avez une nouvelle commande sur " + nomBoutique
						+ " (commande #" + commande.getIdCommande() + "). Connectez-vous a KASUWATA My Buz pour la traiter.";

				Sms sms = new Sms();
				sms.setReceiver(telephone);
				sms.setMessage(message);
				smsService.send(sms);
			}
		} catch (Exception e) {
			System.err.println("[CommandeController] Echec notification SMS vendeur : " + e.getMessage());
		}
	}

	/**
	 * Résout la référence {@link com.techinnov.kassouwata_back.entitites.Produit}
	 * d'une ligne de commande via son ID, afin d'éviter une
	 * {@code TransientPropertyValueException} lors de la sauvegarde en cascade.
	 */
	private void resolveProduit(ProduitCommande ligne) {
		if (ligne.getProduit() != null && ligne.getProduit().getIdProduit() != null) {
			ligne.setProduit(produitRepository.getReferenceById(ligne.getProduit().getIdProduit()));
		}
	}
	
	//Update Commande
	@PutMapping("/update/{id}")
	Commande replaceCommande(@RequestBody Commande newCommande, @PathVariable Long id) {
		return commandeRepository.findById(id)
        .map(commande -> {
        	commande.setDateCommande(newCommande.getDateCommande());
        	commande.setMoyenPaiement(newCommande.getMoyenPaiement());
        	commande.setTypeVente(newCommande.getTypeVente());
        	commande.setAdresseLivraison(newCommande.getAdresseLivraison());
          return commandeRepository.save(commande);
        })
        .orElseGet(() -> {
          newCommande.setIdCommande(id);
          return commandeRepository.save(newCommande);
        });
    }	
	
	// Transitions autorisées par statut courant
	private static final Map<String, Set<String>> TRANSITIONS = Map.of(
		"EN_ATTENTE",   Set.of("CONFIRMEE", "ANNULEE"),
		"CONFIRMEE",    Set.of("EN_LIVRAISON", "ANNULEE"),
		"EN_LIVRAISON", Set.of("LIVREE")
	);

	// Changer le statut d'une commande (vendeur)
	@PatchMapping("/{id}/statut")
	public ResponseEntity<Commande> updateStatut(
			@PathVariable Long id,
			@RequestBody Map<String, String> body) {
		String newStatut = body.get("statut");
		if (newStatut == null) {
			return ResponseEntity.badRequest().build();
		}
		Commande commande = commandeRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Commande not found with id: " + id));
		Set<String> allowed = TRANSITIONS.getOrDefault(commande.getStatut(), Set.of());
		if (!allowed.contains(newStatut)) {
			return ResponseEntity.badRequest().build();
		}
		commande.setStatut(newStatut);
		return ResponseEntity.ok(commandeRepository.save(commande));
	}

	//Cancel Commande (statut EN_ATTENTE → ANNULEE) — conservé pour compatibilité
	@PatchMapping("/cancel/{id}")
	public ResponseEntity<Commande> cancelCommande(@PathVariable Long id) {
		Commande commande = commandeRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Commande not found with id: " + id));
		if (!"EN_ATTENTE".equals(commande.getStatut())) {
			return ResponseEntity.badRequest().build();
		}
		commande.setStatut("ANNULEE");
		return ResponseEntity.ok(commandeRepository.save(commande));
	}

	//Delete Commande
	@DeleteMapping("/delete/{id}")
	public void deleteCommandeById(@PathVariable Long id) {
		commandeRepository.deleteById(id);
	}
		
}