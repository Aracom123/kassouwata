package com.techinnov.kassouwata_back.entitites;

import java.util.Date;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

import com.techinnov.kassouwata_back.enums.DemandeAdhesionStatus;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Data
@Entity
public class DemandeAdhesion extends Auditable<String> {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idDemandeAdhesion;

    /** Numéro invité (conservé pour l'affichage et pour inviter un numéro sans compte). */
    private String telephone;

    /**
     * Compte du membre invité. Les adhésions sont rattachées au compte (et non au
     * numéro) : un changement de numéro ne fait plus perdre les tontines rejointes.
     * Null tant que le numéro invité n'a pas de compte ; renseigné à l'inscription.
     */
    @JsonIgnore
    @EqualsAndHashCode.Exclude
    @ToString.Exclude
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User membre;

    @Temporal(TemporalType.TIMESTAMP)
    private Date dateEnvoi;

    @Enumerated(EnumType.STRING)
    private DemandeAdhesionStatus statut = DemandeAdhesionStatus.ENVOYEE;

    @ManyToOne(fetch = FetchType.LAZY, cascade = CascadeType.DETACH)
    @JoinColumn(name = "tontine_id")
    private Tontine tontine;

    /** Identifiant du compte du membre (null si le numéro n'a pas encore de compte). */
    @JsonProperty("idMembre")
    public UUID getIdMembre() {
        return membre != null ? membre.getIdUser() : null;
    }
}