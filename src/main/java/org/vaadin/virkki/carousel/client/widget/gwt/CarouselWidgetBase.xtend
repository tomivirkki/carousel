package org.vaadin.virkki.carousel.client.widget.gwt

import com.google.gwt.event.dom.client.KeyCodes
import com.google.gwt.event.dom.client.MouseWheelEvent
import com.google.gwt.event.shared.HandlerRegistration
import com.google.gwt.user.client.Event
import com.google.gwt.user.client.ui.Button
import com.google.gwt.user.client.ui.CellPanel
import com.google.gwt.user.client.ui.FlowPanel
import com.google.gwt.user.client.ui.FocusPanel
import com.google.gwt.user.client.ui.HorizontalPanel
import com.google.gwt.user.client.ui.SimplePanel
import com.google.gwt.user.client.ui.Widget
import java.util.List

abstract class CarouselWidgetBase extends FocusPanel {

	val static STYLE_NAME = "carousel"
	val static STYLE_CAROUSEL_PANEL = "carouselpanel"
	val static STYLE_CHILD_PANEL_WRAPPER = "childpanelwrapper"
	val static STYLE_CHILD_PANEL = "childpanel"
	val static STYLE_CAROUSEL_BUTTON = "carouselbutton"
	val static STYLE_PREVIOUS_BUTTON = "previousbutton"
	val static STYLE_NEXT_BUTTON = "nextbutton"

	protected List<Widget> widgets = newArrayList
	val protected List<CarouselWidgetListener> listeners = newArrayList
	
	val protected childPanel = createChildPanel => [styleName = STYLE_CHILD_PANEL]

	protected int index

	boolean hasFocus

	val previousButton = getCarouselButton(true)
	val nextButton = getCarouselButton(false)

	@Property CarouselLoadMode loadMode
	HandlerRegistration arrowKeysHandler
	HandlerRegistration mouseWheelHandler

	new() {
		styleName = STYLE_NAME
		
		widget = new FlowPanel => [
			styleName = STYLE_CAROUSEL_PANEL
			add(new SimplePanel(childPanel) => [styleName = STYLE_CHILD_PANEL_WRAPPER])
			add(previousButton)
			add(nextButton)
		]

		addFocusHandler[hasFocus = true]
		addBlurHandler[hasFocus = false]
	}

	def protected CellPanel createChildPanel()

	def private getCarouselButton(boolean previous) {
		new Button => [
			styleName = STYLE_CAROUSEL_BUTTON
			addStyleName = if(previous) STYLE_PREVIOUS_BUTTON else STYLE_NEXT_BUTTON
			addClickHandler[scroll(if(previous) -1 else 1)]
		]
	}

	def setButtonsVisible(boolean visible) {
		previousButton.setVisible(visible)
		nextButton.setVisible(visible)
	}

	def setMouseWheelEnabled(boolean enabled) {
		mouseWheelHandler?.removeHandler
		mouseWheelHandler = if (enabled)
			childPanel.addDomHandler(
				[
					scroll(deltaY)
					preventDefault
				], MouseWheelEvent::type)
	}

	def setArrowKeysMode(ArrowKeysMode arrowKeysMode) {
		arrowKeysHandler?.removeHandler
		arrowKeysHandler = if (arrowKeysMode != null && arrowKeysMode != ArrowKeysMode::DISABLED) {
			arrowKeysHandler = Event::addNativePreviewHandler [
				if (Event::getTypeInt(nativeEvent.type) == Event::ONKEYDOWN &&
					(arrowKeysMode == ArrowKeysMode::ALWAYS || hasFocus)) {
					switch (nativeEvent.keyCode) {
						case KeyCodes::KEY_RIGHT: if (horizontal) scroll(1)
						case KeyCodes::KEY_LEFT: if (horizontal) scroll(-1)
						case KeyCodes::KEY_DOWN: if (!horizontal) scroll(1)
						case KeyCodes::KEY_UP: if (!horizontal) scroll(-1)
					}
				}]
		}
	}

	def addListener(CarouselWidgetListener listener) {
		listeners.add(listener)
	}

	def void setWidgets(List<Widget> _widgets)

	def protected getSelectedWidget() {
		getWrapper(index).widget
	}

	def protected getWrapper(int index) {
		childPanel.getWidget(index) as SimplePanel
	}

	def scroll(int change) {
		scrollToPanelIndex(index + change)
	}

	def scrollTo(int widgetIndex) {
		widgets.get(widgetIndex).scrollTo
	}

	def scrollTo(Widget widget) {
		val wrapper = widget.parent
		if (wrapper != null) {
			scrollToPanelIndex(childPanel.getWidgetIndex(wrapper))
		}
	}

	def protected void scrollToPanelIndex(int _index)
	
	def protected boolean isHorizontal() {
		childPanel.class == typeof(HorizontalPanel)
	}

}
