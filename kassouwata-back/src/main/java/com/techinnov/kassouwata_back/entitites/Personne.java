package com.techinnov.kassouwata_back.entitites;

import java.util.Collection;
import java.util.Date;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonBackReference;
import com.fasterxml.jackson.annotation.JsonIgnore;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;

/*import javax.validation.constraints.Null;
import javax.validation.constraints.Pattern;*/
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Entity
@Data  
public class Personne extends Auditable<String>{
	@Id
    @GeneratedValue
    private UUID idPersonne;

	
	private String nom;
	private String prenom;

	@Column(nullable =true)
	private String email;

	private String genre;

	private String adresse;

	private Date dateNaissance;

	private String lieuNaissance;	

	private String photo;

	@OneToOne(mappedBy = "personne", optional = false)
    @JoinColumn(
        nullable = false,
        unique = true
    )
	@JsonBackReference
	// Relation bidirectionnelle avec User : exclue de equals/hashCode/toString
	// sinon User.hashCode -> Personne.hashCode -> User.hashCode... (StackOverflowError)
	@ToString.Exclude
	@EqualsAndHashCode.Exclude
    private User user;
}
