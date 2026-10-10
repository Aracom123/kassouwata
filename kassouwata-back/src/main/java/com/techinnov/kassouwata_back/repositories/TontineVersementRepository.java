package com.techinnov.kassouwata_back.repositories;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.techinnov.kassouwata_back.entitites.TontineVersement;

public interface TontineVersementRepository extends JpaRepository<TontineVersement, UUID> {

    @Query("SELECT v FROM TontineVersement v WHERE v.tontinePeriodeVersement.idTontinePeriodeVersement = :idPeriode ORDER BY v.dateVersement DESC")
    List<TontineVersement> findByPeriodeId(@Param("idPeriode") Long idPeriode);

    /** Le membre a-t-il déjà cotisé pour cette période ? */
    boolean existsByMembre_IdUserAndTontinePeriodeVersement_IdTontinePeriodeVersement(UUID idUser, Long idPeriode);
}
