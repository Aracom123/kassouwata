package com.techinnov.kassouwata_back.repositories;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.techinnov.kassouwata_back.entitites.TontineVersement;

public interface TontineVersementRepository extends JpaRepository<TontineVersement, UUID> {

    @Query("SELECT v FROM TontineVersement v WHERE v.tontinePeriodeVersement.idTontinePeriodeVersement = :idPeriode ORDER BY v.dateVersement DESC")
    List<TontineVersement> findByPeriodeId(@Param("idPeriode") Long idPeriode);

    /** Le membre a-t-il déjà cotisé pour cette période ? */
    boolean existsByMembre_IdUserAndTontinePeriodeVersement_IdTontinePeriodeVersement(UUID idUser, Long idPeriode);

    /** Rattache au compte correspondant les cotisations enregistrées avec un simple numéro. */
    @Modifying
    @Query(value = "UPDATE tontine_versement v SET user_id = u.id_user FROM utilisateur u "
            + "WHERE v.user_id IS NULL AND v.telephone = u.telephone", nativeQuery = true)
    int lierAuxComptes();

    /** Reporte un changement de numéro sur les cotisations du membre. */
    @Modifying
    @Query(value = "UPDATE tontine_versement SET telephone = :nouveau "
            + "WHERE user_id = :idUser OR (user_id IS NULL AND telephone = :ancien)", nativeQuery = true)
    int changerTelephone(@Param("idUser") UUID idUser, @Param("ancien") String ancien,
                         @Param("nouveau") String nouveau);
}
