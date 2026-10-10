package com.techinnov.kassouwata_back.repositories;

import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import com.techinnov.kassouwata_back.entitites.Transaction;

public interface TransactionRepository extends JpaRepository<Transaction, Long>, JpaSpecificationExecutor<Transaction> {
	List<Transaction> findByCommande_IdCommande(Long idCommande);

	Optional<Transaction> findByReferenceExterne(String referenceExterne);

	/** Transactions à vérifier auprès de l'agrégateur (ex. EN_ATTENTE créées dans une plage de temps). */
	List<Transaction> findByStatutAndDateTransactionBetween(String statut, Date debut, Date fin);

	/**
	 * Montant déjà payé sur une commande.
	 * Compte les transactions REUSSIE et les anciennes transactions sans statut
	 * (enregistrées avant l'intégration de l'agrégateur).
	 */
	@Query("SELECT COALESCE(SUM(t.montant), 0) FROM Transaction t "
			+ "WHERE t.commande.idCommande = :idCommande AND (t.statut IS NULL OR t.statut = 'REUSSIE')")
	double sumMontantPayeByCommande(@Param("idCommande") Long idCommande);

	/** Paiement déjà en cours sur cette commande (évite un double paiement). */
	boolean existsByCommande_IdCommandeAndStatutAndDateTransactionAfter(Long idCommande, String statut, Date apres);

	/** Cotisation déjà en cours pour ce membre et cette période (évite un double paiement). */
	boolean existsByTontinePeriodeVersement_IdTontinePeriodeVersementAndUtilisateur_IdUserAndStatutAndDateTransactionAfter(
			Long idPeriode, UUID idUser, String statut, Date apres);

	/**
	 * Passe une transaction de EN_ATTENTE au nouveau statut, de façon atomique.
	 * Renvoie 1 si le changement a eu lieu, 0 si la transaction n'était plus EN_ATTENTE
	 * (déjà traitée par une autre vérification) : le paiement n'est ainsi comptabilisé qu'une fois.
	 */
	@Modifying(clearAutomatically = true, flushAutomatically = true)
	@Transactional
	@Query("UPDATE Transaction t SET t.statut = :statut WHERE t.idTransaction = :id AND t.statut = 'EN_ATTENTE'")
	int changerStatutSiEnAttente(@Param("id") Long id, @Param("statut") String statut);

	// ------------------------------------------------------------------
	// Statistiques (back-office)
	// ------------------------------------------------------------------

	/** [statut, nombre, montant] — statut null = transaction enregistrée manuellement. */
	@Query("SELECT t.statut, COUNT(t), COALESCE(SUM(t.montant), 0) FROM Transaction t GROUP BY t.statut")
	List<Object[]> statistiquesParStatut();

	/** [moyenPaiement, nombre, montant] des transactions réussies. */
	@Query("SELECT t.moyenPaiement, COUNT(t), COALESCE(SUM(t.montant), 0) FROM Transaction t "
			+ "WHERE t.statut = 'REUSSIE' GROUP BY t.moyenPaiement")
	List<Object[]> encaissementsParFournisseur();

	/** [typeOperation, nombre, montant] des transactions réussies. */
	@Query("SELECT t.typeOperation, COUNT(t), COALESCE(SUM(t.montant), 0) FROM Transaction t "
			+ "WHERE t.statut = 'REUSSIE' GROUP BY t.typeOperation")
	List<Object[]> encaissementsParTypeOperation();
}
