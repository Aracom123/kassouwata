package com.techinnov.kassouwata_back.entitites;

import java.util.Collection;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

@Data
@Entity
@Table(name="profile")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
//@JsonIdentityInfo(generator=ObjectIdGenerators.IntSequenceGenerator.class)
public class Profile extends Auditable<String>{
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long idProfile;
	
	@Column(name = "libelle")
	private String libelle;
	
	@Column(name = "description")
	private String description;
	
	// @ManyToMany
	// @JoinTable(
	// 		name = "profile_has_action",
	// 				joinColumns = @JoinColumn(name = "profile_id"),
	// 				inverseJoinColumns = @JoinColumn(name = "action_id")
	// 		)
	// private Collection<Actions> actions;
	// //Set<Action>  actions = new HashSet<>();

	public Profile() {
		super();
	}
	
}

