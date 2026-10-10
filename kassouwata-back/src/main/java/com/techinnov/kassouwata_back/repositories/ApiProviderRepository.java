package com.techinnov.kassouwata_back.repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import com.techinnov.kassouwata_back.entitites.ApiProvider;

public interface ApiProviderRepository extends JpaRepository<ApiProvider, Long> {
	
}
