package org.vaadin.virkki.carousel.client.widget

import com.google.gwt.core.client.GWT
import com.vaadin.shared.ui.Connect
import org.vaadin.virkki.carousel.HorizontalCarousel
import org.vaadin.virkki.carousel.client.widget.gwt.CarouselWidgetBase
import org.vaadin.virkki.carousel.client.widget.gwt.HorizontalCarouselWidget

@SuppressWarnings("serial")
@Connect(HorizontalCarousel)
class HorizontalCarouselConnector extends AbstractCarouselConnector {

	override protected createWidget() {
		GWT::create(HorizontalCarouselWidget) => [
			(it as CarouselWidgetBase).addListener(rpc)
		]
	}

	override HorizontalCarouselWidget getWidget() {
		super.widget as HorizontalCarouselWidget
	}

}
