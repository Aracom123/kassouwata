package com.techinnov.kassouwata_back.entitites;

import java.util.Collection;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonManagedReference;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;

@Entity
public class ApiParam {
	@Id
    @GeneratedValue(strategy = GenerationType.IDENTITY )
	private long idApiParam;
	
	private String key;
	
	private String value;
	
	@JsonBackReference(value="params")
	@ManyToOne
	private Api api;

	public ApiParam() {
		super();
		// TODO Auto-generated constructor stub
	}

	public long getIdApiParam() {
		return idApiParam;
	}

	public void setIdApiParam(long idApiParam) {
		this.idApiParam = idApiParam;
	}

	public String getKey() {
		return key;
	}

	public void setKey(String key) {
		this.key = key;
	}

	public String getValue() {
		return value;
	}

	public void setValue(String value) {
		this.value = value;
	}

	public Api getApi() {
		return api;
	}

	public void setApi(Api api) {
		this.api = api;
	}
}
