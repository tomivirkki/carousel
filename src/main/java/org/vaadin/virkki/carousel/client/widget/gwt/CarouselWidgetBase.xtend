package org.vaadin.virkki.carousel.client.widget.gwt

import com.google.gwt.event.dom.client.KeyCodes
import com.google.gwt.event.dom.client.MouseWheelEvent
import com.google.gwt.event.shared.HandlerRegistration
import com.google.gwt.user.client.Event
import com.google.gwt.user.client.ui.Button
import com.google.gwt.user.client.ui.CellPanel
import com.google.gwt.user.client.ui.FlowPanel
import com.google.gwt.user.client.ui.FocusPanel
import com.google.gwt.user.client.ui.SimplePanel
import com.google.gwt.user.client.ui.Widget
import java.util.List

abstract class CarouselWidgetBase extends FocusPanel {

	val static STYLE_NAME = "carousel"
	val static STYLE_CAROUSEL_PANEL = "carouselpanel"
	val static STYLE_CHILD_PANEL_WRAPPER = "childpanelwrapper"
	val static STYLE_CHILD_PANEL = "childpanel"
	val static STYLE_CAROUSEL_BUTTON = "carouselbutton"
	val static STYLE_LEFT_BUTTON = "leftbutton"
	val static STYLE_RIGHT_BUTTON = "rightbutton"

	protected List<Widget> widgets = newArrayList
	val protected List<CarouselWidgetListener> listeners = newArrayList
	
	val protected childPanel = createChildPanel => [styleName = STYLE_CHILD_PANEL]

	protected int index

	boolean hasFocus

	val leftButton = getCarouselButton(true)
	val rightButton = getCarouselButton(false)

	@Property CarouselLoadMode loadMode
	HandlerRegistration arrowKeysHandler
	HandlerRegistration mouseWheelHandler

	new() {
		styleName = STYLE_NAME
		
		widget = new FlowPanel => [
			styleName = STYLE_CAROUSEL_PANEL
			add(new SimplePanel(childPanel) => [styleName = STYLE_CHILD_PANEL_WRAPPER])
			add(leftButton)
			add(rightButton)
		]

		addFocusHandler[hasFocus = true]
		addBlurHandler[hasFocus = false]
	}

	def protected CellPanel createChildPanel()

	def private getCarouselButton(boolean left) {
		new Button => [
			styleName = STYLE_CAROUSEL_BUTTON
			addStyleName = if(left) STYLE_LEFT_BUTTON else STYLE_RIGHT_BUTTON
			addClickHandler[scroll(if(left) -1 else 1)]
		]
	}

	def setButtonsVisible(boolean visible) {
		leftButton.setVisible(visible)
		rightButton.setVisible(visible)
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
						case KeyCodes::KEY_RIGHT: scroll(1)
						case KeyCodes::KEY_LEFT: scroll(-1)
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

}
