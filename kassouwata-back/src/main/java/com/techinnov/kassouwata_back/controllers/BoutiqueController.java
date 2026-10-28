package com.techinnov.kassouwata_back.controllers;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.rest.webmvc.ResourceNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.techinnov.kassouwata_back.controllers.dto.CreateBoutiqueRequest;
import com.techinnov.kassouwata_back.entitites.Boutique;
import com.techinnov.kassouwata_back.entitites.User;
import com.techinnov.kassouwata_back.enums.BoutiqueStatus;
import com.techinnov.kassouwata_back.repositories.BoutiqueRepository;
import com.techinnov.kassouwata_back.repositories.CommandeRepository;
import com.techinnov.kassouwata_back.repositories.ProduitRepository;
import com.techinnov.kassouwata_back.repositories.UserRepository;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosBoutiques")
public class BoutiqueController {
	@Autowired
	private BoutiqueRepository boutiqueRepository;

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private CommandeRepository commandeRepository;

	@Autowired
	private ProduitRepository produitRepository;

	
	//Get All Boutiques
	@GetMapping("/list")
	public Page<Boutique> getAllBoutiques(Pageable page){
		return boutiqueRepository.findAll(page);
	}

	/** Boutiques visibles par le public (statut ACTIVE) — applications mobiles. */
	@GetMapping("/actives")
	public Page<Boutique> getBoutiquesActives(Pageable page){
		return boutiqueRepository.findByStatus(BoutiqueStatus.ACTIVE, page);
	}

	/** Retourne la boutique d'un vendeur par son UUID utilisateur */
	@GetMapping("/byVendeur/{idUser}")
	public ResponseEntity<?> getBoutiqueByVendeur(@PathVariable String idUser) {
		try {
			UUID uuid = UUID.fromString(idUser);
			Boutique boutique = boutiqueRepository.getUserByVendeurID(uuid);
			if (boutique == null) {
				return ResponseEntity.notFound().build();
			}
			return ResponseEntity.ok(boutique);
		} catch (IllegalArgumentException e) {
			return ResponseEntity.badRequest().body("Format UUID invalide : " + idUser);
		}
	}

	//Get Boutique By Id
	@GetMapping("/{id}")
	public ResponseEntity<Boutique> getBoutiqueById(@PathVariable Long id){
		Boutique boutique = boutiqueRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Boutique not exit with id:" +id));
		 return ResponseEntity.ok(boutique);
	
	}
		
	/**
	 * Création d'une boutique depuis l'application mobile vendeur.
	 * Accepte { "libelle", "adresse", "description", "vendeur": { "idUser": "uuid" } }
	 * et résout le User depuis la base pour éviter les erreurs de désérialisation UUID.
	 */
	@PostMapping("/save")
	public ResponseEntity<?> addBoutique(@RequestBody CreateBoutiqueRequest request) {
		String vendeurId = request.resolveVendeurId();
		if (vendeurId == null || vendeurId.isBlank()) {
			return ResponseEntity.badRequest().body("Le champ vendeur.idUser est obligatoire.");
		}

		UUID uuid;
		try {
			uuid = UUID.fromString(vendeurId);
		} catch (IllegalArgumentException e) {
			return ResponseEntity.badRequest().body("Format UUID invalide : " + vendeurId);
		}

		User vendeur = userRepository.findById(uuid)
				.orElseThrow(() -> new ResourceNotFoundException("Vendeur introuvable avec l'id : " + vendeurId));

		// Une seule boutique par vendeur
		if (boutiqueRepository.getUserByVendeurID(uuid) != null) {
			return ResponseEntity.status(HttpStatus.CONFLICT)
					.body("Ce vendeur possède déjà une boutique.");
		}

		// Seul un administrateur peut créer une boutique directement active :
		// une boutique créée depuis l'application attend la validation.
		boolean admin = estAdmin();

		Boutique boutique = new Boutique();
		boutique.setLibelle(request.getLibelle());
		boutique.setDescription(request.getDescription());
		boutique.setAdresse(request.getAdresse());
		boutique.setLatitude(request.getLatitude());
		boutique.setLongitude(request.getLongitude());
		boutique.setVendeur(vendeur);
		boutique.setStatus(
			admin && request.getStatus() != null
				? BoutiqueStatus.valueOf(request.getStatus())
				: BoutiqueStatus.PENDING
		);

		return ResponseEntity.status(HttpStatus.CREATED).body(boutiqueRepository.save(boutique));
	}
	
	//Add Boutique
	// @GetMapping("/getCandidatBoutique")
	// public Boutique getBoutiqueByLibelle(@RequestParam("libelle") String libelle) {
	// 	return boutiqueRepository.findBoutiqueByLibelle(libelle);
	// }
	
	/** L'utilisateur connecté est-il administrateur ? */
	private boolean estAdmin() {
		var auth = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication();
		return auth != null && auth.getAuthorities().stream()
				.anyMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()));
	}

	//Update Boutique
	@PutMapping("/update/{id}")
	Boutique replaceBoutique(@RequestBody Boutique newBoutique, @PathVariable Long id) {
		return boutiqueRepository.findById(id)
        .map(boutique -> {
        	boutique.setLibelle(newBoutique.getLibelle());
        	boutique.setDescription(newBoutique.getDescription());
        	boutique.setAdresse(newBoutique.getAdresse());
        	boutique.setLatitude(newBoutique.getLatitude());
        	boutique.setLongitude(newBoutique.getLongitude());
        	// Le vendeur ne change pas (sauf si un vendeur valide est fourni)
        	if (newBoutique.getVendeur() != null && newBoutique.getVendeur().getIdUser() != null) {
        		userRepository.findById(newBoutique.getVendeur().getIdUser())
        				.ifPresent(boutique::setVendeur);
        	}
        	// Statut et commission : réservés à l'administrateur. Une modification
        	// depuis l'application vendeur ne doit ni réactiver ni remettre
        	// « En attente » une boutique.
        	if (estAdmin()) {
        		if (newBoutique.getStatus() != null) boutique.setStatus(newBoutique.getStatus());
        		boutique.setCommission(newBoutique.getCommission());
        	}
          return boutiqueRepository.save(boutique);
        })
        .orElseGet(() -> {
          newBoutique.setIdBoutique(id);
          return boutiqueRepository.save(newBoutique);
        });
    }	
	
	//Delete Boutique
	@DeleteMapping("/delete/{id}")
	public void deleteBoutiqueById(@PathVariable Long id) {
		boutiqueRepository.deleteById(id);
	}

	/** Statistiques détaillées d'une boutique */
	@GetMapping("/{id}/stats")
	public Map<String, Object> getStatsBoutique(@PathVariable Long id) {
		Map<String, Object> stats = new LinkedHashMap<>();

		stats.put("nombreProduits",        produitRepository.getNombreProduitsByBoutique(id));
		stats.put("nombreProduitsPublies", produitRepository.getNombreProduitsPubliesByBoutique(id));
		stats.put("nombreCommandes",       commandeRepository.getNombreCommandesByBoutique(id));
		stats.put("commandesLivrees",      commandeRepository.getNombreCommandesLivreesByBoutique(id));
		stats.put("commandesEnAttente",    commandeRepository.getNombreCommandesEnAttenteByBoutique(id));
		stats.put("chiffreAffaires",       commandeRepository.getCAByBoutique(id));
		stats.put("totalCommissions",      commandeRepository.getCommissionsByBoutique(id));

		int total  = commandeRepository.getNombreCommandesByBoutique(id);
		int livrees = commandeRepository.getNombreCommandesLivreesByBoutique(id);
		stats.put("tauxLivraison", total > 0 ? Math.round((livrees * 100.0) / total) : 0);

		return stats;
	}
}