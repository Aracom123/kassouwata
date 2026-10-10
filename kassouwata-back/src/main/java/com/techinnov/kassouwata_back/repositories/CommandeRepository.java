package com.techinnov.kassouwata_back.repositories;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.techinnov.kassouwata_back.entitites.Commande;

public interface CommandeRepository extends JpaRepository<Commande, Long> {

	@Query("SELECT c FROM Commande c ORDER BY c.created_at DESC")
	List<Commande> findAllOrderByCreatedAtDesc();

	@Query("SELECT c FROM Commande c WHERE c.client.idUser = :idUser ORDER BY c.created_at DESC")
	List<Commande> findByClient_IdUser(@Param("idUser") UUID idUser);

	@Query("SELECT DISTINCT c FROM Commande c JOIN c.lignes l WHERE l.produit.boutique.idBoutique = :idBoutique ORDER BY c.created_at DESC")
	List<Commande> findByBoutiqueId(@Param("idBoutique") Long idBoutique);

	@Query("SELECT DISTINCT COUNT(*) FROM Commande ")
	int getNombreCommandes();

	@Query(value = "SELECT DISTINCT COUNT(*) FROM utilisateur WHERE profile_id=2", nativeQuery = true)
	int getNombreVendeur();

	@Query(value = "SELECT DISTINCT COUNT(*) FROM utilisateur WHERE profile_id=3", nativeQuery = true)
	int getNombreClient();

	@Query(value = "SELECT COALESCE(SUM(montant_total), 0) FROM commande WHERE statut = 'LIVREE'", nativeQuery=true)
	double getCA();

	@Query(value = "SELECT DISTINCT COUNT(*) FROM commande ", nativeQuery=true)
	double getNombreVente();

	@Query(value = "SELECT COUNT(*) FROM commande WHERE statut = 'EN_ATTENTE'", nativeQuery=true)
	int getNombreCommandesEnAttente();

	@Query(value = "SELECT COUNT(*) FROM commande WHERE statut = 'CONFIRMEE'", nativeQuery=true)
	int getNombreCommandesConfirmees();

	@Query(value = "SELECT COUNT(*) FROM commande WHERE statut = 'EN_LIVRAISON'", nativeQuery=true)
	int getNombreCommandesEnLivraison();

	@Query(value = "SELECT COUNT(*) FROM commande WHERE statut = 'LIVREE'", nativeQuery=true)
	int getNombreCommandesLivrees();

	@Query(value = "SELECT COUNT(*) FROM commande WHERE statut = 'ANNULEE'", nativeQuery=true)
	int getNombreCommandesAnnulees();

	/**
	 * Calcule les commissions perçues : somme de (prixUnitaire * quantite * commission_boutique / 100)
	 * pour toutes les lignes de commandes livrées.
	 */
	@Query(value = """
		SELECT COALESCE(SUM(pc.prix_unitaire * pc.quantite * b.commission / 100), 0)
		FROM produit_commande pc
		JOIN commande c ON c.id_commande = pc.commande_id
		JOIN produit p ON p.id_produit = pc.produit_id
		JOIN boutique b ON b.id_boutique = p.boutique_id
		WHERE c.statut = 'LIVREE'
		""", nativeQuery=true)
	double getTotalCommissions();

	/** CA du mois courant (PostgreSQL) */
	@Query(value = "SELECT COALESCE(SUM(montant_total), 0) FROM commande WHERE statut = 'LIVREE' AND EXTRACT(MONTH FROM created_at) = EXTRACT(MONTH FROM CURRENT_DATE) AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM CURRENT_DATE)", nativeQuery=true)
	double getCAMoisCourant();

	/**
	 * Évolution mensuelle CA + commissions pour l'année courante.
	 * Retourne une ligne par mois (1-12) avec : mois, ca, commissions.
	 * Seules les commandes LIVREE sont comptabilisées.
	 */
	// ── Stats par boutique ───────────────────────────────────────────────────

	@Query(value = """
		SELECT COUNT(DISTINCT c.id_commande)
		FROM commande c
		JOIN produit_commande pc ON pc.commande_id = c.id_commande
		JOIN produit p ON p.id_produit = pc.produit_id
		WHERE p.boutique_id = :idBoutique
		""", nativeQuery=true)
	int getNombreCommandesByBoutique(@Param("idBoutique") Long idBoutique);

	@Query(value = """
		SELECT COUNT(DISTINCT c.id_commande)
		FROM commande c
		JOIN produit_commande pc ON pc.commande_id = c.id_commande
		JOIN produit p ON p.id_produit = pc.produit_id
		WHERE p.boutique_id = :idBoutique AND c.statut = 'LIVREE'
		""", nativeQuery=true)
	int getNombreCommandesLivreesByBoutique(@Param("idBoutique") Long idBoutique);

	@Query(value = """
		SELECT COUNT(DISTINCT c.id_commande)
		FROM commande c
		JOIN produit_commande pc ON pc.commande_id = c.id_commande
		JOIN produit p ON p.id_produit = pc.produit_id
		WHERE p.boutique_id = :idBoutique AND c.statut = 'EN_ATTENTE'
		""", nativeQuery=true)
	int getNombreCommandesEnAttenteByBoutique(@Param("idBoutique") Long idBoutique);

	@Query(value = """
		SELECT COALESCE(SUM(c.montant_total), 0)
		FROM commande c
		JOIN produit_commande pc ON pc.commande_id = c.id_commande
		JOIN produit p ON p.id_produit = pc.produit_id
		WHERE p.boutique_id = :idBoutique AND c.statut = 'LIVREE'
		""", nativeQuery=true)
	double getCAByBoutique(@Param("idBoutique") Long idBoutique);

	@Query(value = """
		SELECT COALESCE(SUM(pc.prix_unitaire * pc.quantite * b.commission / 100.0), 0)
		FROM produit_commande pc
		JOIN commande c ON c.id_commande = pc.commande_id
		JOIN produit p ON p.id_produit = pc.produit_id
		JOIN boutique b ON b.id_boutique = p.boutique_id
		WHERE b.id_boutique = :idBoutique AND c.statut = 'LIVREE'
		""", nativeQuery=true)
	double getCommissionsByBoutique(@Param("idBoutique") Long idBoutique);

	@Query(value = """
		SELECT
		    EXTRACT(MONTH FROM c.created_at)::int                                          AS mois,
		    COALESCE(SUM(c.montant_total), 0)                                              AS ca,
		    COALESCE(SUM(pc.prix_unitaire * pc.quantite * b.commission / 100.0), 0)        AS commissions
		FROM commande c
		LEFT JOIN produit_commande pc ON pc.commande_id = c.id_commande
		LEFT JOIN produit p           ON p.id_produit   = pc.produit_id
		LEFT JOIN boutique b          ON b.id_boutique  = p.boutique_id
		WHERE c.statut = 'LIVREE'
		  AND EXTRACT(YEAR FROM c.created_at) = EXTRACT(YEAR FROM CURRENT_DATE)
		GROUP BY EXTRACT(MONTH FROM c.created_at)
		ORDER BY mois
		""", nativeQuery=true)
	List<Object[]> getEvolutionMensuelle();
}
