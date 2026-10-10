package com.techinnov.kassouwata_back.entitites;


import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import com.techinnov.kassouwata_back.enums.UserStatus;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Data 
@Table(name = "utilisateur")
public class User extends Auditable<String>{
	@Id
    @GeneratedValue
    @Column(name = "id_user", updatable = false, nullable = false)
    private UUID idUser;

	// @Column(unique=true)
    // private String username;

    private String password;

    @Column(nullable = false, unique = true)
    private String telephone;
    
    @ManyToOne(fetch = FetchType.LAZY, cascade=CascadeType.DETACH)
    @JoinColumn(name ="profile_id")
	private Profile profile;

    @Enumerated(EnumType.STRING)
    private UserStatus status = UserStatus.PHONE_UNVERIFIED;

    @OneToOne(cascade = CascadeType.ALL)  // <-- cascade ici
    @JoinColumn(name = "personne_id")
    @JsonManagedReference
    private Personne personne;
	
}

