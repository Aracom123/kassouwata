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
public class Api extends Auditable<String>{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY )
	private long idApi;
	
	private String libelle;
	
	private String baseUrl;
	
	private int typeApi;
	
	private String method;
	
	private String description;
	
	private String login;
	
	private String password;
	
	// @ManyToOne
	// private Pays pays;
	
	@ManyToOne 
	private ApiProvider provider;
	
	@JsonManagedReference(value="params")
	@OneToMany(mappedBy = "api", cascade = CascadeType.ALL,
            orphanRemoval = true)
	private Collection<ApiParam> params;

	public Api() {
		super();
		// TODO Auto-generated constructor stub
	}

	public Api(long idApi, String libelle, String baseUrl, String parameters) {
		super();
		this.idApi = idApi;
		this.libelle = libelle;
		this.baseUrl = baseUrl;
	}

	public long getIdApi() {
		return idApi;
	}

	public void setIdApi(long idApi) {
		this.idApi = idApi;
	}

	public String getLibelle() {
		return libelle;
	}

	public void setLibelle(String libelle) {
		this.libelle = libelle;
	}

	public String getBaseUrl() {
		return baseUrl;
	}

	public void setBaseUrl(String baseUrl) {
		this.baseUrl = baseUrl;
	}

	// public Pays getPays() {
	// 	return pays;
	// }

	// public void setPays(Pays pays) {
	// 	this.pays = pays;
	// }

	public int getTypeApi() {
		return typeApi;
	}

	public void setTypeApi(int typeApi) {
		this.typeApi = typeApi;
	}

	public ApiProvider getProvider() {
		return provider;
	}

	public void setProvider(ApiProvider provider) {
		this.provider = provider;
	}

	public Collection<ApiParam> getParams() {
		return params;
	}

	public void setParams(Collection<ApiParam> params) {
		this.params = params;
	}

	public String getMethod() {
		return method;
	}

	public void setMethod(String method) {
		this.method = method;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public String getLogin() {
		return login;
	}

	public void setLogin(String login) {
		this.login = login;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}
}
