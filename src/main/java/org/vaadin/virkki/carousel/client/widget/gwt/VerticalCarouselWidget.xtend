package org.vaadin.virkki.carousel.client.widget.gwt

import com.google.gwt.user.client.ui.VerticalPanel
import com.google.gwt.dom.client.Style
import com.google.gwt.user.client.ui.Widget

class VerticalCarouselWidget extends DraggableCarouselWidget {

	val static STYLE_NAME = "verticalcarousel"

	new(){
		super()
		addStyleName(STYLE_NAME)
	}

	override protected createChildPanel(){
		return new VerticalPanel
	}
	
	override protected updateChildPanelMargin() {
		childPanel.element.style.setMarginTop(currentMargin, Style$Unit::PX)
	}
	
	override protected isHorizontal() {
		false
	}
	
	override protected getMeasure() {
		height
	}
	
	override protected setChildPanelPosition(double position) {
		childPanel.element.style.setTop(position, Style$Unit::PX)
	}
	
	override protected getPositionRelativeToCarousel(Widget widget) {
		widget.element.absoluteTop - element.absoluteTop
	}
	
	override protected getChildPanelCurrentPosition() {
		childPanel.element.absoluteTop - currentMargin - (
			if(OPERA) 0 else element.offsetTop
		)
	}
	
}
