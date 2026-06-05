function _coral_doctor_value --argument-names name value
    if contains -- "$name" $__coral_config_explicit
        _coral_doctor_ok "$name=$$name resolved=$value"
    else
        _coral_doctor_ok "$name default=$value"
    end
end
