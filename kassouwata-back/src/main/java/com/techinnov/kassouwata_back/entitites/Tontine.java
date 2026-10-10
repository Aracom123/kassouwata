package com.techinnov.kassouwata_back.entitites;

import java.util.Date;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.Data;

@Data
@Entity
public class Tontine extends Auditable<String>{
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idTontine;

    private String libelle;

    private String description;

    private Date dateDebut;

    private Date dateFin;

    private double montant;

    private String periodicite;

    @ManyToOne(fetch = FetchType.LAZY, cascade=CascadeType.DETACH)
    @JoinColumn(name ="user_id")
    private User tontineOwner;
}
