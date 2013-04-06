package org.vaadin.virkki.carousel.client.widget.gwt

import com.google.gwt.user.client.ui.HorizontalPanel

class HorizontalCarouselWidget extends DraggableCarouselWidget {

	val static STYLE_NAME = "horizontalcarousel"

	new(){
		super()
		addStyleName(STYLE_NAME)
	}

	override protected createChildPanel(){
		return new HorizontalPanel
	}
}
