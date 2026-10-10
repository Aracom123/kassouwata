package com.techinnov.kassouwata_back.repositories;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.techinnov.kassouwata_back.entitites.MoyenPaiement;

public interface MoyenPaiementRepository extends JpaRepository<MoyenPaiement, Long> {

	Optional<MoyenPaiement> findByCode(String code);

	List<MoyenPaiement> findAllByOrderByOrdreAsc();
}
