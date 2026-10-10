package com.techinnov.kassouwata_back.entitites;

import java.util.Collection;

import com.fasterxml.jackson.annotation.JsonManagedReference;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;

@Entity
public class ApiProvider extends Auditable<String>{
	@Id
    @GeneratedValue(strategy = GenerationType.IDENTITY )
	protected long idApiProvider;
	
	@Column(name="raisonSociale")
	private String raisonSociale;
	
	@Column(name="telephone")
	private String telephone;
	
	@Column(name="email")
	private String email;
	
	@Column(name="rccm")
	private String rccm;
	
	@Column(name="nif")
	private String nif;
	
	@Column(name="logo")
	private String logo;

	public ApiProvider() {
		super();
		// TODO Auto-generated constructor stub
	}

	public long getIdApiProvider() {
		return idApiProvider;
	}

	public void setIdApiProvider(long idApiProvider) {
		this.idApiProvider = idApiProvider;
	}

	public String getRaisonSociale() {
		return raisonSociale;
	}

	public void setRaisonSociale(String raisonSociale) {
		this.raisonSociale = raisonSociale;
	}

	public String getTelephone() {
		return telephone;
	}

	public void setTelephone(String telephone) {
		this.telephone = telephone;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getRccm() {
		return rccm;
	}

	public void setRccm(String rccm) {
		this.rccm = rccm;
	}

	public String getNif() {
		return nif;
	}

	public void setNif(String nif) {
		this.nif = nif;
	}

	public String getLogo() {
		return logo;
	}

	public void setLogo(String logo) {
		this.logo = logo;
	}
}
