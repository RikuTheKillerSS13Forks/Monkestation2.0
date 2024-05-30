// Symptom Signals //

/// Sent by symptoms on the first valid cycle in a row. (host, disease)
#define COMSIG_SYMPTOM_ACTIVATE_PASSIVE "symptom_activate_passive"
/// Sent by symptoms on the first invalid cycle in a row. (host, disease)
#define COMSIG_SYMPTOM_DEACTIVATE_PASSIVE "symptom_deactivate_passive"

/// Sent by symptoms every cycle regardless of validity. (host, disease, potency, seconds_per_tick)
#define COMSIG_SYMPTOM_PROCESS_ANY "symptom_process_any"
/// Sent by symptoms every valid cycle. (host, disease, potency, seconds_per_tick)
#define COMSIG_SYMPTOM_PROCESS_ACTIVE "symptom_process_active"
/// Sent by symptoms every invalid cycle. (host, disease, potency, seconds_per_tick)
#define COMSIG_SYMPTOM_PROCESS_INACTIVE "symptom_process_inactive"


// Activator Signals //

/// Sent by activators on the first valid cycle in a row. (symptom, host, disease)
#define COMSIG_ACTIVATOR_ACTIVATE_PASSIVE "activator_activate_passive"
/// Sent by activators on the first invalid cycle in a row. (symptom, host, disease)
#define COMSIG_ACTIVATOR_DEACTIVATE_PASSIVE "activator_activate_passive"

/// Sent by activators every cycle regardless of validity. (symptom, host, disease, potency, seconds_per_tick)
#define COMSIG_ACTIVATOR_PROCESS_ANY "activator_process_any"
/// Sent by activators every valid cycle. (symptom, host, disease, potency, seconds_per_tick)
#define COMSIG_ACTIVATOR_PROCESS_ACTIVE "activator_process_active"
/// Sent by activators every invalid cycle. (symptom, host, disease, potency, seconds_per_tick)
#define COMSIG_ACTIVATOR_PROCESS_INACTIVE "activator_process_inactive"
