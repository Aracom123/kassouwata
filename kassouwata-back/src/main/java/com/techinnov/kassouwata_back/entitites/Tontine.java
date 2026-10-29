package com.techinnov.kassouwata_back.entitites;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.techinnov.kassouwata_back.enums.StatutAdashe;
import com.techinnov.kassouwata_back.enums.TypeAdashe;

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

    // ── Adashé Produit (achat groupé d'un produit) ─────────────────────────
    // Pour un Adashé classique ces champs restent vides (null = CLASSIQUE / ACTIF).

    @Enumerated(EnumType.STRING)
    private TypeAdashe typeAdashe;

    @Enumerated(EnumType.STRING)
    private StatutAdashe statutAdashe;

    /** Produit acheté par le groupe */
    @ManyToOne(fetch = FetchType.EAGER, cascade = CascadeType.DETACH)
    @JoinColumn(name = "produit_id")
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Produit produit;

    /** Nombre de membres prévu (créateur compris) */
    private Integer nombreMembres;

    /** Nombre de périodes de cotisation */
    private Integer nombrePeriodes;

    /** Montant à réunir (prix du produit) */
    private Double montantCible;

    /** true : visible sur la page du produit, tout acheteur peut rejoindre */
    private Boolean ouverte;

    /** Motif du refus par le vendeur */
    private String motifRefus;

    public boolean estProduit() {
        return typeAdashe == TypeAdashe.PRODUIT;
    }

    public StatutAdashe statutEffectif() {
        return statutAdashe != null ? statutAdashe : StatutAdashe.ACTIF;
    }
}
