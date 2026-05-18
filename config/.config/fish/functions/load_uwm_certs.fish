function load_uwm_certs
    if test $TERM_PROGRAM = 'zed'
        set UWM_CERT "$HOME/uwm-certs/uwm-ca-bundle.pem"
        if test -f $UWM_CERT
            export NODE_EXTRA_CA_CERTS=$UWM_CERT
            echo "loaded $UWM_CERT"
        else
            echo "couldn't find $UWM_CERT"
        end
    else
        set UWM_CERT "$HOME/uwm-certs/uwm-ca-bundle.crt"
        if test -f $UWM_CERT
            export NODE_EXTRA_CA_CERTS=$UWM_CERT
            echo "loaded $UWM_CERT"
        else
            echo "couldn't find $UWM_CERT"
        end
    end
end
