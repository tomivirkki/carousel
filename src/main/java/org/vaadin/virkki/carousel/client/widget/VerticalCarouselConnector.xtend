package org.vaadin.virkki.carousel.client.widget

import com.google.gwt.core.client.GWT
import com.vaadin.shared.ui.Connect
import org.vaadin.virkki.carousel.VerticalCarousel
import org.vaadin.virkki.carousel.client.widget.gwt.CarouselWidgetBase
import org.vaadin.virkki.carousel.client.widget.gwt.VerticalCarouselWidget

@SuppressWarnings("serial")
@Connect(VerticalCarousel)
class VerticalCarouselConnector extends AbstractCarouselConnector {

	override protected createWidget() {
		GWT::create(VerticalCarouselWidget) => [
			(it as CarouselWidgetBase).addListener(rpc)
		]
	}

	override VerticalCarouselWidget getWidget() {
		super.widget as VerticalCarouselWidget
	}

}
