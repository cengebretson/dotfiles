function _coral_doctor_command --argument-names name
    if command -q "$name"
        _coral_doctor_ok "$name available"
        return 0
    end

    _coral_doctor_fail "$name missing"
    return 1
end
