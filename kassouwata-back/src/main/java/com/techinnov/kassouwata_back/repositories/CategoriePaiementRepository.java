package com.techinnov.kassouwata_back.repositories;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.techinnov.kassouwata_back.entitites.CategoriePaiement;

public interface CategoriePaiementRepository extends JpaRepository<CategoriePaiement, Long> {

	Optional<CategoriePaiement> findByCode(String code);

	List<CategoriePaiement> findAllByOrderByOrdreAsc();
}
