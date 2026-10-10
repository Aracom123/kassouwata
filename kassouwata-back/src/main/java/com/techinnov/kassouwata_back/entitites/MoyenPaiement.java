package com.techinnov.kassouwata_back.entitites;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.Data;

/**
 * Moyen (fournisseur) de paiement : Airtel Money, MyNita, Amana, Visa, MasterCard...
 *
 * - code           : identifiant interne, identique aux valeurs déjà stockées en base
 *                    (Transaction.moyenPaiement, TontineVersement.fournisseur).
 * - codeAgregateur : valeur du champ "mobile_money" envoyée à KomiPay
 *                    (airtel_money, nita_transfert, amana_transfert, bank_card...).
 * - logo           : nom du fichier image (servi par GET /api/payment/logos/{logo}).
 */
@Data
@Entity
public class MoyenPaiement extends Auditable<String> {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long idMoyenPaiement;

    @Column(nullable = false, unique = true, length = 30)
    private String code;

    private String libelle;

    private String codeAgregateur;

    private String logo;

    private Integer ordre = 0;

    private Boolean actif = true;

    @JsonIgnore
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "categorie_paiement_id")
    private CategoriePaiement categorie;

    @JsonProperty("categorieCode")
    public String getCategorieCode() {
        return categorie != null ? categorie.getCode() : null;
    }

    /** Chemin de l'image, à préfixer par l'URL de l'API (ex. http://serveur:8082/api). */
    @JsonProperty("logoPath")
    public String getLogoPath() {
        return logo != null && !logo.isBlank() ? "/payment/logos/" + logo : null;
    }

    /** Utilisable pour un paiement : actif, catégorie active et code KomiPay renseigné. */
    @JsonIgnore
    public boolean isUtilisable() {
        return Boolean.TRUE.equals(actif)
                && categorie != null && Boolean.TRUE.equals(categorie.getActif())
                && codeAgregateur != null && !codeAgregateur.isBlank();
    }
}
