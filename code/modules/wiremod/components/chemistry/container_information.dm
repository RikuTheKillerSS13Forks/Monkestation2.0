/obj/item/circuit_component/variable/container_information
	display_name = "Container Information"
	desc = "Reads data from chemical containers."
	category = "Chemistry"

	circuit_flags = CIRCUIT_FLAG_INPUT_SIGNAL | CIRCUIT_FLAG_OUTPUT_SIGNAL

	power_usage_per_input = 0
	circuit_size = 1

	var/datum/port/output/total_volume_port
	var/datum/port/output/maximum_volume_port
	var/datum/port/output/temperature_port

/obj/item/circuit_component/variable/container_information/populate_ports()
	total_volume_port = add_output_port("Total Volume", PORT_TYPE_NUMBER)
	maximum_volume_port = add_output_port("Maximum Volume", PORT_TYPE_NUMBER)
	temperature_port = add_output_port("Temperature", PORT_TYPE_NUMBER)

/obj/item/circuit_component/variable/container_information/input_received(datum/port/input/port, list/return_values)
	if (!current_variable)
		total_volume_port.set_value(null)
		maximum_volume_port.set_value(null)
		temperature_port.set_value(null)
		return

	var/datum/reagents/container = current_variable

	total_volume_port.set_value(container.total_volume)
	maximum_volume_port.set_value(container.maximum_volume)
	temperature_port.set_value(container.chem_temp)
