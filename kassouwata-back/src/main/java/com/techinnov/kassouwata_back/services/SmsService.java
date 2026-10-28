package com.techinnov.kassouwata_back.services;

import java.util.Arrays;
import java.util.Collection;

import org.json.simple.JSONObject;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import com.techinnov.kassouwata_back.entitites.Api;
import com.techinnov.kassouwata_back.entitites.ApiParam;
import com.techinnov.kassouwata_back.entitites.Sms;
import com.techinnov.kassouwata_back.repositories.ApiRepository;
import com.techinnov.kassouwata_back.repositories.SmsRepository;

@Service
public class SmsService {

    private static final String SENDER = "MyBuz";

    @Autowired
    private ApiRepository apiRepository;

    @Autowired
    private SmsRepository smsRepository;

    @Autowired
    private RestTemplate restTemplate;

    /**
     * Envoie un SMS via l'API configurée (type 0).
     * Le champ "from" est toujours "MyBuz".
     * Persiste le log en base et retourne l'objet Sms mis à jour.
     */
    public Sms send(Sms sms) {
        Api api = apiRepository.findByType(0);
        if (api == null) {
            System.err.println("[SmsService] Aucune API SMS configurée (type=0).");
            sms.setStatut(false);
            sms.setResponse("Aucune API SMS configurée.");
            return smsRepository.save(sms);
        }

        String authorization = api.getLogin() + ":" + api.getPassword();
        String base64Creds = java.util.Base64.getEncoder()
                .encodeToString(authorization.getBytes());

        HttpHeaders headers = new HttpHeaders();
        headers.setAccept(Arrays.asList(MediaType.APPLICATION_JSON));
        headers.set("Authorization", "Basic " + base64Creds);

        // Alphabet GSM 7 bits uniquement : les accents font passer le SMS en
        // Unicode, ce que certains opérateurs / passerelles refusent.
        sms.setMessage(versGsm7(sms.getMessage()));

        JSONObject payload = new JSONObject();
        payload.put("to", sms.getReceiver());
        payload.put("from", SENDER);
        payload.put("content", sms.getMessage());

        Collection<ApiParam> params = api.getParams();
        if (params != null) {
            for (ApiParam param : params) {
                payload.put(param.getKey(), param.getValue());
            }
        }

        System.out.println("[SmsService] Envoi SMS : " + payload);

        HttpEntity<JSONObject> entity = new HttpEntity<>(payload, headers);
        sms.setSender(SENDER);
        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    api.getBaseUrl(), HttpMethod.POST, entity, String.class);
            String resp = response.getBody() != null ? response.getBody() : "";
            sms.setResponse(resp);
            sms.setStatut(resp.contains("Success"));
            if (!sms.isStatut()) {
                System.err.println("[SmsService] SMS refusé par le fournisseur pour "
                        + sms.getReceiver() + " : " + resp);
            }
        } catch (HttpStatusCodeException e) {
            // Erreur HTTP du fournisseur (crédit épuisé, identifiants, numéro refusé…) :
            // on la conserve en base pour pouvoir diagnostiquer.
            String detail = "HTTP " + e.getStatusCode().value() + " : " + e.getResponseBodyAsString();
            System.err.println("[SmsService] Échec envoi SMS à " + sms.getReceiver() + " — " + detail);
            sms.setStatut(false);
            sms.setResponse(detail);
        } catch (RestClientException e) {
            System.err.println("[SmsService] Fournisseur SMS injoignable : " + e.getMessage());
            sms.setStatut(false);
            sms.setResponse("Fournisseur injoignable : " + e.getMessage());
        }

        return smsRepository.save(sms);
    }

    /** Retire accents et caractères hors alphabet GSM 7 bits (é → e, ’ → ', « » → "). */
    static String versGsm7(String texte) {
        if (texte == null) return "";
        String t = java.text.Normalizer.normalize(texte, java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{Mn}", "");
        t = t.replace('\u2019', '\'').replace('\u2018', '\'')
             .replace('\u00AB', '"').replace('\u00BB', '"')
             .replace('\u2013', '-').replace('\u2014', '-')
             .replace('\u00A0', ' ');
        return t;
    }
}
