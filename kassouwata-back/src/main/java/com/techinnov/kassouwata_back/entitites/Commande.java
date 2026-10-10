package com.techinnov.kassouwata_back.entitites;


import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Data
@Entity
public class Commande extends Auditable<String> {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idCommande;

    private Date dateCommande;

    private String statut = "EN_ATTENTE";

    /**
     * Type de vente (mode de paiement) : PREPAYE ou POSTPAYE.
     * - PREPAYE  : la commande ne contient qu'un seul produit ; le paiement s'effectue
     *              en plusieurs tranches définies par Produit.nombreTranches.
     * - POSTPAYE : la commande peut contenir plusieurs produits, paiement en une fois.
     */
    private String typeVente;

    private String moyenPaiement;

    private Double montantTotal;

    private String adresseLivraison;

    @ManyToOne(fetch = FetchType.LAZY, cascade=CascadeType.DETACH)
    @JoinColumn(name ="user_id")
    private User client;

    @com.fasterxml.jackson.annotation.JsonIgnoreProperties("commande")
    @OneToMany(mappedBy = "commande", fetch = FetchType.EAGER, cascade = CascadeType.ALL)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude   // évite la boucle Commande <-> ProduitCommande
    private List<ProduitCommande> lignes = new ArrayList<>();

    @com.fasterxml.jackson.annotation.JsonIgnoreProperties("commande")
    @OneToMany(mappedBy = "commande", fetch = FetchType.EAGER, cascade = CascadeType.DETACH)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude   // évite la boucle Commande <-> Transaction
    private List<Transaction> versements = new ArrayList<>();
}
