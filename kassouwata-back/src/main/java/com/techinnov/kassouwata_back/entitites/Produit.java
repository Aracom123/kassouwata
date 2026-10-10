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
public class Produit extends Auditable<String> {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idProduit;

    private String libelle;

    private String description;
    
    private double prixUnitaire;   
     
    private int quantite;

    private String imagePrincipale;
    private String photos;
    private Boolean statut=false;

    /**
     * Nombre de tranches pour le paiement prépayé.
     * Définit en combien de versements le client peut régler ce produit
     * lorsque le mode de paiement de la commande est PREPAYE.
     * Null ou 0 signifie que le paiement en tranches n'est pas disponible pour ce produit.
     */
    private Integer nombreTranches;

    @ManyToOne(fetch = FetchType.LAZY, cascade=CascadeType.DETACH)
    @JoinColumn(name ="categorie_id")
	private Categorie categorie;

    @ManyToOne(fetch = FetchType.EAGER, cascade=CascadeType.DETACH)
    @JoinColumn(name ="boutique_id")
    @com.fasterxml.jackson.annotation.JsonIgnoreProperties({"vendeur", "lignes", "versements", "hibernateLazyInitializer", "handler"})
	private Boutique boutique;
}
