package org.vaadin.virkki.carousel.client.widget.gwt

interface CarouselWidgetListener {
	def void widgetSelected(int selectedIndex)
	
	def void requestWidgets(int selectedIndex)
}
