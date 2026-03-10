<?php

if(!defined('DOKU_INC')) die();

/**
 * HTTP/LDAP authentication backend
 * HTTP (your web server) handle the authentication
 * LDAP handle user informations, and group membership
 * This plugin have been written to work with LemonLDAP::NG WebSSO
 * @license   GPL 2 (http://www.gnu.org/licenses/gpl.html)
 * @author    Daniel Berteaud <daniel@firewall-services.com>
 */

require(DOKU_PLUGIN."authldap/auth.php");
class auth_plugin_authhttpldap extends auth_plugin_authldap {
    /**
     * Constructor
     */
    public function __construct() {
        parent::__construct();

        // ldap extension is needed
        if(!function_exists('ldap_connect')) {
            $this->debug("LDAP err: PHP LDAP extension not found.", -1, __LINE__, __FILE__);
            $this->success = false;
            return;
        }
        $this->cando = array (
            'addUser'     => false, // can Users be created?
            'delUser'     => false, // can Users be deleted?
            'modLogin'    => false, // can login names be changed?
            'modPass'     => false, // can passwords be changed?
            'modName'     => false, // can real names be changed?
            'modMail'     => false, // can emails be changed?
            'modGroups'   => false, // can groups be changed?
            'getUsers'    => true,  // can a (filtered) list of users be retrieved?
            'getUserCount'=> false, // can the number of users be retrieved?
            'getGroups'   => true,  // can a list of available groups be retrieved?
            'external'    => true,  // does the module do external auth checking?
            'logout'      => true,  // can the user logout again? (eg. not possible with HTTP auth)
        );
    }

    /**
    * Check if REMOTE_USER is set
    */
    function trustExternal($user,$pass,$sticky=false){
        global $USERINFO;
        $success = false;
        if (!isset($_SERVER['REMOTE_USER'])) return false;
        $username = $_SERVER['REMOTE_USER'];
        $this->debug('HTTP User Name: '.htmlspecialchars($username),0,__LINE__,__FILE__);
        if (!empty($username)){
            $USERINFO = $this->getUserData($username,true);
            if ($USERINFO !== false){
                $success = true;
                $_SESSION[DOKU_COOKIE]['auth']['user'] = $username;
                $_SESSION[DOKU_COOKIE]['auth']['info'] = $USERINFO;
            }
        }
        return $success;
    }
}
