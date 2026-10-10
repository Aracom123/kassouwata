package com.techinnov.kassouwata_back.entitites;

import java.util.Date;

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

@Data
@Entity
public class DemandeAdhesion extends Auditable<String> {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idDemandeAdhesion;

    private String telephone;

    @Temporal(TemporalType.TIMESTAMP)
    private Date dateEnvoi;

    @Enumerated(EnumType.STRING)
    private DemandeAdhesionStatus statut = DemandeAdhesionStatus.ENVOYEE;

    @ManyToOne(fetch = FetchType.LAZY, cascade = CascadeType.DETACH)
    @JoinColumn(name = "tontine_id")
    private Tontine tontine;
}