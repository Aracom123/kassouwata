package com.techinnov.kassouwata_back.repositories;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.techinnov.kassouwata_back.entitites.DemandeAdhesion;

public interface DemandeAdhesionRepository extends JpaRepository<DemandeAdhesion, Long> {

    @Query("SELECT d FROM DemandeAdhesion d WHERE d.tontine.idTontine = :idTontine ORDER BY d.dateEnvoi DESC")
    List<DemandeAdhesion> findByTontineId(@Param("idTontine") Long idTontine);

    /** Demandes reçues par un utilisateur : rattachées à son compte, ou à son numéro si pas encore liées. */
    @Query("SELECT d FROM DemandeAdhesion d LEFT JOIN d.membre m "
            + "WHERE m.idUser = :idUser OR (m IS NULL AND d.telephone = :telephone) "
            + "ORDER BY d.dateEnvoi DESC")
    List<DemandeAdhesion> findPourUtilisateur(@Param("idUser") UUID idUser,
                                              @Param("telephone") String telephone);

    /** Rattache au compte correspondant les demandes qui ne sont liées qu'à un numéro. */
    @Modifying
    @Query(value = "UPDATE demande_adhesion d SET user_id = u.id_user FROM utilisateur u "
            + "WHERE d.user_id IS NULL AND d.telephone = u.telephone", nativeQuery = true)
    int lierAuxComptes();

    /** Reporte un changement de numéro sur les demandes du membre. */
    @Modifying
    @Query(value = "UPDATE demande_adhesion SET telephone = :nouveau "
            + "WHERE user_id = :idUser OR (user_id IS NULL AND telephone = :ancien)", nativeQuery = true)
    int changerTelephone(@Param("idUser") UUID idUser, @Param("ancien") String ancien,
                         @Param("nouveau") String nouveau);
}