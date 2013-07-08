package org.vaadin.virkki.carousel.client.widget.gwt

import com.google.gwt.user.client.ui.HorizontalPanel
import com.google.gwt.dom.client.Style
import com.google.gwt.user.client.ui.Widget

class HorizontalCarouselWidget extends DraggableCarouselWidget {

	val static STYLE_NAME = "horizontalcarousel"

	new() {
		super()
		addStyleName(STYLE_NAME)
	}

	override protected createChildPanel() {
		return new HorizontalPanel
	}

	override protected updateChildPanelMargin() {
		childPanel.element.style.setMarginLeft(currentMargin, Style$Unit::PX)
	}

	override protected isHorizontal() {
		true
	}

	override protected getMeasure() {
		width
	}

	override protected setChildPanelPosition(double position) {
		childPanel.element.style.setLeft(position, Style$Unit::PX)
	}

	override protected getPositionRelativeToCarousel(Widget widget) {
		widget.element.absoluteLeft - element.absoluteLeft
	}

	override protected getChildPanelCurrentPosition() {
		childPanel.element.absoluteLeft - currentMargin - (
			if(OPERA) 0 else element.offsetLeft
		)
	}
}
