package com.techinnov.kassouwata_back.controllers;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.techinnov.kassouwata_back.entitites.Sms;
import com.techinnov.kassouwata_back.services.SmsService;

@CrossOrigin("*")
@RestController
@RequestMapping("/api/nosSms")
public class SmsController {

    @Autowired
    private SmsService smsService;

    @PostMapping("/send")
    public Sms sendSms(@RequestBody Sms sms) {
        return smsService.send(sms);
    }

    @PostMapping("/testsend")
    public Sms sendTestSms(@RequestBody Sms sms) {
        return smsService.send(sms);
    }
}
