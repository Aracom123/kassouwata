package com.techinnov.kassouwata_back.entitites;

import lombok.AccessLevel;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedBy;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import jakarta.persistence.Column;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.Temporal;
import jakarta.persistence.TemporalType;

import java.util.Date;

@Getter(AccessLevel.PROTECTED)
@Setter(AccessLevel.PROTECTED)
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class Auditable<U> {

    @CreatedBy
    @Column(name = "created_by")
    private U created_by;


    @CreatedDate
    @Temporal(TemporalType.TIMESTAMP)
    @Column(name = "created_at")
    private Date created_at;
    

    @LastModifiedBy
    @Column(name = "modified_by")
    private U modified_by;


    @LastModifiedDate
    @Column(name = "modified_at")
    private Date modified_at;


	public U getCreated_by() {
		return created_by;
	}


	public void setCreated_by(U created_by) {
		this.created_by = created_by;
	}


	public Date getCreated_at() {
		return created_at;
	}


	public void setCreated_at(Date created_at) {
		this.created_at = created_at;
	}


	public U getModified_by() {
		return modified_by;
	}


	public void setModified_by(U modified_by) {
		this.modified_by = modified_by;
	}


	public Date getModified_at() {
		return modified_at;
	}


	public void setModified_at(Date modified_at) {
		this.modified_at = modified_at;
	}
    
    
}
