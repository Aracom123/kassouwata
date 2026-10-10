package com.techinnov.kassouwata_back.entitites;

import com.techinnov.kassouwata_back.enums.BoutiqueStatus;

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
public class Boutique extends Auditable<String> {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idBoutique;

    private String libelle;

    private String description;

    private String adresse;

    private Double latitude;

    private Double longitude;

    private double commission = 5.0;

    @Enumerated(EnumType.STRING)
    private BoutiqueStatus status = BoutiqueStatus.PENDING;

    @ManyToOne(fetch = FetchType.LAZY, cascade=CascadeType.DETACH)
    @JoinColumn(name ="user_id")
    private User vendeur;
}
