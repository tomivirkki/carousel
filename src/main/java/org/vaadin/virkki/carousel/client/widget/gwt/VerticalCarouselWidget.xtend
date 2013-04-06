package org.vaadin.virkki.carousel.client.widget.gwt

import com.google.gwt.user.client.ui.VerticalPanel

class VerticalCarouselWidget extends DraggableCarouselWidget {

	val static STYLE_NAME = "verticalcarousel"

	new(){
		super()
		addStyleName(STYLE_NAME)
	}

	override protected createChildPanel(){
		return new VerticalPanel
	}
}
