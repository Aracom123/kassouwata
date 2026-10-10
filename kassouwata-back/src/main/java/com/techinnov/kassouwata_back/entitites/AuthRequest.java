/**
 * 
 */
package com.techinnov.kassouwata_back.entitites;

/**
 * @author BAKO ADAMOU Mamane Bariki
 *
 */
public class AuthRequest {
	
	private String login;
	
	private String password;


	public AuthRequest() {
		super();
		// TODO Auto-generated constructor stub
	}

	/**
	 * @param login
	 * @param password
	 */
	public AuthRequest(String login, String password) {
		super();
		this.login = login;
		this.password = password;
	}

	/**
	 * @return the login
	 */
	public String getLogin() {
		return login;
	}

	/**
	 * @param login the login to set
	 */
	public void setLogin(String login) {
		this.login = login;
	}

	/**
	 * @return the password
	 */
	public String getPassword() {
		return password;
	}

	/**
	 * @param password the password to set
	 */
	public void setPassword(String password) {
		this.password = password;
	}
	
	

}

