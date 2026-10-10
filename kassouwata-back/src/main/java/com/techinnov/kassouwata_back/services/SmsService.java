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
        ResponseEntity<String> response = restTemplate.exchange(
                api.getBaseUrl(), HttpMethod.POST, entity, String.class);

        String resp = response.getBody() != null ? response.getBody() : "";
        sms.setSender(SENDER);
        sms.setResponse(resp);
        sms.setStatut(resp.contains("Success"));

        return smsRepository.save(sms);
    }
}
