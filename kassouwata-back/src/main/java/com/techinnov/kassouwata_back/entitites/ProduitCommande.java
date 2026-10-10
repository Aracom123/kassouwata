package com.techinnov.kassouwata_back.entitites;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
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
public class ProduitCommande extends Auditable<String> {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idProduitCommande;

    private int quantite;

    private double prixUnitaire;

    @ManyToOne(fetch = FetchType.EAGER, cascade=CascadeType.DETACH)
    @JoinColumn(name ="produit_id")
    Produit produit;

    @ManyToOne(fetch = FetchType.LAZY, cascade=CascadeType.DETACH)
    @JoinColumn(name ="commande_id")
    Commande commande;
}
