/obj/item/circuit_component/variable/container_interface
	display_name = "Container Interface"
	desc = "Interfaces with chemical containers, allowing you to put chemicals in and take them out."
	category = "Chemistry"

	power_usage_per_input = 5
	circuit_size = 1 // The main limiter is the number of containers you can make, not the number of interfaces you can have to those containers.

	ui_buttons = list(
		"plus" = "add",
		"minus" = "remove"
	)

	var/datum/reagents/transfer_container

	var/list/chemical_input_ports = list()

	var/datum/port/input/output_amount_port
	var/datum/port/input/handle_output_port
	var/datum/port/input/handle_input_port

	var/datum/port/output/chemical_output_port
	var/datum/port/output/output_handled_port
	var/datum/port/output/input_handled_port

/obj/item/circuit_component/variable/container_interface/Initialize(mapload)
	. = ..()
	transfer_container = new(10000)
	transfer_container.my_atom = src

/obj/item/circuit_component/variable/container_interface/get_variable_list(obj/item/integrated_circuit/integrated_circuit)
	return integrated_circuit.reagent_container_variables

/obj/item/circuit_component/variable/container_interface/populate_ports()
	AddComponent(/datum/component/circuit_component_add_port, \
		port_list = chemical_input_ports, \
		add_action = "add", \
		remove_action = "remove", \
		port_type = PORT_TYPE_CHEMICAL_LIST, \
		prefix = "Chemical Input", \
		minimum_amount = 1 \
	)

	output_amount_port = add_input_port("Output Amount", PORT_TYPE_NUMBER)
	handle_output_port = add_input_port("Handle Output", PORT_TYPE_SIGNAL, trigger = PROC_REF(handle_output))
	handle_input_port = add_input_port("Handle Input", PORT_TYPE_SIGNAL, trigger = PROC_REF(handle_input))

	chemical_output_port = add_output_port("Chemical Output", PORT_TYPE_CHEMICAL_LIST)
	output_handled_port = add_output_port("Output Handled", PORT_TYPE_SIGNAL)
	input_handled_port = add_output_port("Input Handled", PORT_TYPE_SIGNAL)

/obj/item/circuit_component/variable/container_interface/proc/handle_output(datum/port/input/port, list/return_values)
	if (!current_variable)
		return
	var/datum/reagents/container = current_variable.value

	container.trans_to(transfer_container, output_amount_port.value)

	var/list/output_reagents = list()
	for(var/datum/reagent/reagent as anything in transfer_container.reagent_list)
		output_reagents[reagent.type] = reagent.volume

	chemical_output_port.set_output(output_reagents)
	output_handled_port.set_output(COMPONENT_SIGNAL)
	transfer_container.clear_reagents()

/obj/item/circuit_component/variable/container_interface/proc/handle_input(datum/port/input/port, list/return_values)
	if (!current_variable)
		return
	var/datum/reagents/container = current_variable.value

	var/list/input_reagents = list()
	for(var/datum/port/input/input_port as anything in chemical_input_ports)
		input_reagents += input_port.value

	container.add_reagent_list(input_reagents)
	input_handled_port.set_output(COMPONENT_SIGNAL)

/obj/item/circuit_component/variable/container_interface/after_work_call()
	chemical_output_port.value = null
	for(var/datum/port/input/input_port as anything in chemical_input_ports)
		input_port.value = null
