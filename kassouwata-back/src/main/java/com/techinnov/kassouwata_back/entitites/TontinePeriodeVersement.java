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
public class TontinePeriodeVersement extends Auditable<String>{
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idTontinePeriodeVersement;

    private String libelle;

    private Date dateDebut;

    private Date dateFin;

    @ManyToOne(fetch = FetchType.LAZY, cascade=CascadeType.DETACH)
    @JoinColumn(name ="user_id")
    private User beneficiaire;

    @ManyToOne(fetch = FetchType.LAZY, cascade=CascadeType.DETACH)
    @JoinColumn(name ="tontine_id")
    private Tontine tontine;
}
