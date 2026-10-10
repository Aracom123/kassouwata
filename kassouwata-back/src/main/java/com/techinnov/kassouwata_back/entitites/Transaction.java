package com.techinnov.kassouwata_back.entitites;


import java.util.Date;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

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
import lombok.EqualsAndHashCode;
import lombok.ToString;

@Data
@Entity
public class Transaction extends Auditable<String> {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idTransaction;

    private Date dateTransaction;

    /**
     * Catégorie de paiement : CASH_LIVRAISON | MOBILE_MONEY | STA | CARTE
     */
    private String modePaiement;

    /**
     * Code du moyen de paiement (table moyen_paiement) : AIRTEL_MONEY | NITA | AMANA | VISA | MASTERCARD...
     * (null pour CASH_LIVRAISON)
     */
    private String moyenPaiement;

    private double montant;

    @ManyToOne(fetch = FetchType.LAZY, cascade = CascadeType.DETACH)
    @JoinColumn(name = "commande_id")
    private Commande commande;

    // ------------------------------------------------------------------
    // Paiement via l'agrégateur
    // ------------------------------------------------------------------

    /** Référence unique envoyée à l'agrégateur, ex. CMD-125-1728230400. */
    @Column(unique = true, length = 100)
    private String referenceExterne;

    /** EN_ATTENTE | REUSSIE | ECHOUEE (voir enums.StatutTransaction). */
    private String statut;

    /** Objet payé : COMMANDE | TONTINE (voir enums.TypeOperationPaiement). */
    private String typeOperation;

    private String telephonePayeur;

    /** Nom saisi par le payeur (titulaire de la carte, nom du payeur Mobile Money). */
    private String nomPayeur;

    /** Carte bancaire : uniquement les 4 derniers chiffres (**** **** **** 4444). */
    private String numeroCarteMasque;

    /** Réponse brute de l'agrégateur à l'envoi du paiement (JSON), utile en cas de litige. */
    @Column(columnDefinition = "TEXT")
    private String reponseAgregateur;

    /** Réponse brute de la dernière vérification de statut (/check-transaction-status). */
    @Column(columnDefinition = "TEXT")
    private String reponseVerification;

    private Date dateVerification;

    /** Renseignée quand typeOperation = TONTINE. */
    @JsonIgnore
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    @ManyToOne(fetch = FetchType.LAZY, cascade = CascadeType.DETACH)
    @JoinColumn(name = "tontine_id")
    private Tontine tontine;

    /** Période de cotisation payée, quand typeOperation = TONTINE. */
    @JsonIgnore
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    @ManyToOne(fetch = FetchType.LAZY, cascade = CascadeType.DETACH)
    @JoinColumn(name = "periode_versement_id")
    private TontinePeriodeVersement tontinePeriodeVersement;

    /** Utilisateur connecté qui a initié le paiement (client ou membre de la tontine). */
    @JsonIgnore
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    @ManyToOne(fetch = FetchType.LAZY, cascade = CascadeType.DETACH)
    @JoinColumn(name = "user_id")
    private User utilisateur;

    // Le JSON n'expose que les identifiants (évite de charger les entités liées)

    @JsonProperty("tontineId")
    public Long getTontineId() {
        return tontine != null ? tontine.getIdTontine() : null;
    }

    @JsonProperty("periodeVersementId")
    public Long getPeriodeVersementId() {
        return tontinePeriodeVersement != null ? tontinePeriodeVersement.getIdTontinePeriodeVersement() : null;
    }

    @JsonProperty("utilisateurId")
    public java.util.UUID getUtilisateurId() {
        return utilisateur != null ? utilisateur.getIdUser() : null;
    }
}
