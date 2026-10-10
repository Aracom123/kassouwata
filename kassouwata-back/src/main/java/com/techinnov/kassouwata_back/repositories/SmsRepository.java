package com.techinnov.kassouwata_back.repositories;

import org.springframework.data.jpa.repository.JpaRepository;

import com.techinnov.kassouwata_back.entitites.Sms;

public interface SmsRepository extends JpaRepository<Sms, Long> {
	
}