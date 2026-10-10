package com.techinnov.kassouwata_back.entitites;

import java.util.Collection;

import com.fasterxml.jackson.annotation.JsonManagedReference;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;

@Entity
public class Sms extends Auditable<String>{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY )
	private long idSms;
	
	private String receiver;
	
	private String sender;
	
	private String message;
	
	private String response;
	
	private boolean statut;
	
	@ManyToOne 
	private Api api;

	public Sms() {
		super();
		// TODO Auto-generated constructor stub
	}

	public long getIdSms() {
		return idSms;
	}



	public void setIdSms(long idSms) {
		this.idSms = idSms;
	}

	public String getReceiver() {
		return receiver;
	}

	public void setReceiver(String receiver) {
		this.receiver = receiver;
	}

	public String getSender() {
		return sender;
	}

	public void setSender(String sender) {
		this.sender = sender;
	}

	public String getMessage() {
		return message;
	}

	public void setMessage(String message) {
		this.message = message;
	}

	public Api getApi() {
		return api;
	}

	public void setApi(Api api) {
		this.api = api;
	}

	public String getResponse() {
		return response;
	}

	public void setResponse(String response) {
		this.response = response;
	}

	public boolean isStatut() {
		return statut;
	}

	public void setStatut(boolean statut) {
		this.statut = statut;
	}
	
	
	
}
