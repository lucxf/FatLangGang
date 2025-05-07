is_installed_freepbx(){
    log_info "Verificando si FreePBX está instalado..."
    if [ -n "$(dpkg -l | grep freepbx | head -n 1)" ]; then
        log_info "FreePBX está instalado en el sistema 💪"
    else   
        log_info "FreePBX no está instalado en el sistema🥹"
        log_info "Descargando script de instalación ⬇️"
        wget $SCRIPT_URL -O $SCRIPT_PATH
        log_info "Ejecutando script de instalación 👀"
        bash $SCRIPT_PATH

        if [ $? -eq 0 ]; then
            log_info "El script de instalación se ejecutó correctamente ✅"
        else
            log_error "El script de instalación falló ❌"
        fi
    fi
}