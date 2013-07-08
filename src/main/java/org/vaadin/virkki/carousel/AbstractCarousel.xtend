package org.vaadin.virkki.carousel

import com.vaadin.server.Sizeable
import com.vaadin.ui.AbstractComponentContainer
import com.vaadin.ui.Component
import java.util.List
import org.vaadin.virkki.carousel.client.widget.CarouselClientScrollRpc
import org.vaadin.virkki.carousel.client.widget.CarouselClientScrollToRpc
import org.vaadin.virkki.carousel.client.widget.CarouselServerRpc
import org.vaadin.virkki.carousel.client.widget.CarouselState
import org.vaadin.virkki.carousel.client.widget.gwt.ArrowKeysMode
import org.vaadin.virkki.carousel.client.widget.gwt.CarouselLoadMode

abstract class AbstractCarousel extends AbstractComponentContainer implements CarouselServerRpc {

	List<Component> components = newArrayList
	List<ComponentSelectListener> listeners = newArrayList
	var Component selectedComponent

	new() {
		registerRpc(this)
		setHeight(300.0f, Sizeable.Unit::PIXELS)
		setWidth(300.0f, Sizeable.Unit::PIXELS)
	}

	override protected CarouselState getState() {
		super.getState() as CarouselState
	}

	override getComponentCount() {
		addedComponents.size
	}

	/**
	 * Add a new component to the Carousel
	 */
	override addComponent(Component c) {
		components += c
		ensureConnectorsList
	}

	/**
	 * Removes a Component from the Carousel
	 */
	override removeComponent(Component c) {
		components -= c
		super.removeComponent(c)
		ensureConnectorsList
	}

	override replaceComponent(Component oldComponent, Component newComponent) {
		val index = components.indexOf(oldComponent)
		if (index != -1) {
			components.remove(index)
			components.add(index, newComponent)
			fireComponentDetachEvent(oldComponent)
			fireComponentAttachEvent(newComponent)
			markAsDirty()
		}
		ensureConnectorsList
	}

	override iterator() {
		addedComponents.iterator
	}

	def private getAddedComponents() {
		state.connectors.filter(Component)
	}

	/**
	 * Scroll the Carousel forward or backward.
	 * 
	 * @param change
     *            specifies the direction and the number of steps to take 
	 */
	def scroll(int change) {
		CarouselClientScrollRpc.rpcProxy.scroll(change)
	}

	/**
	 * Scroll the Carousel to a specific Component.
	 * 
	 * @param component
     *            the Component to scroll to
	 */
	def scrollTo(Component component) {
		val index = components.indexOf(component)
		if (index > -1) {
			CarouselClientScrollToRpc.rpcProxy.scrollTo(index)
		}
	}

	/**
	 * Load mode defines how child components are fetched from server to client.
	 * LAZY: Child components are not fetched until they're navigated to.
	 * EAGER: All child Components are fetched at once during the initial load.
	 * SMART (default): Initially only the first visible Component, the Component next 
	 * to it and the previous one are fetched. Once they're rendered, Carousel will 
	 * start fetching the rest of the components on the background.
	 */
	def setLoadMode(CarouselLoadMode loadMode) {
		state.loadMode = loadMode
	}

	def getLoadMode() {
		state.loadMode
	}

	/**
	 * Enable/Disable mouse dragging.
	 */
	def setMouseDragEnabled(boolean enabled) {
		state.mouseDragEnabled = enabled
	}

	def isMouseDragEnabled() {
		state.mouseDragEnabled
	}

	/**
	 * Enable/Disable touch dragging.
	 */
	def setTouchDragEnabled(boolean enabled) {
		state.touchDragEnabled = enabled
	}

	def isTouchDragEnabled() {
		state.touchDragEnabled
	}

	/**
	 * Defines how Carousel reacts to arrow keys.
	 * FOCUS: Arrow key presses are only handled when the carousel has focus.
	 * ALWAYS: Arrow key presses are always handled, no matter where the focus is.
	 * DISABLED: Arrow keys are disabled.
	 */
	def setArrowKeysMode(ArrowKeysMode arrowKeysMode) {
		state.arrowKeysMode = arrowKeysMode
	}

	def getArrowKeysMode() {
		state.arrowKeysMode
	}

	/**
	 * Enable/Disable mouse wheel navigation.
	 */
	def setMouseWheelEnabled(boolean enabled) {
		state.mouseWheelEnabled = enabled
	}

	def isMouseWheelEnabled() {
		state.mouseWheelEnabled
	}

	/**
	 * Show/hide the navigation buttons.
	 */
	def setButtonsVisible(boolean visible) {
		state.buttonsVisible = visible
	}

	def isButtonsVisible() {
		state.buttonsVisible
	}

	/**
	 * Set the duration for transition animations.
	 */
	def setTransitionDuration(int durationInMilliseconds) {
		state.transitionDuration = durationInMilliseconds
	}

	def getTransitionDuration() {
		state.transitionDuration
	}

	/**
	 * Add a Component select listener.
	 */
	def addComponentSelectListener(ComponentSelectListener listener) {
		listeners += listener
	}

	def removeComponentSelectListener(ComponentSelectListener listener) {
		listeners -= listener
	}

	override widgetSelected(int selectedIndex) {
		if (selectedIndex >= 0 && selectedIndex < components.size) {
			val selected = components.get(selectedIndex)
			if (selected != selectedComponent) {
				listeners.forEach[componentSelected(selected)]
				selectedComponent = selected
			}
		}
	}

	def private ensureConnectorsList() {

		//Ensure connectors list is not shorter than components
		while (state.connectors.size < components.size) {
			state.connectors.add(null)
		}

		//Ensure connectors list is not longer than components
		while (components.size < state.connectors.size) {
			val connector = state.connectors.last
			state.connectors -= connector
			remove(connector as Component);
		}

		//Ensure connectors list contains no anomalies
		for (i : 0 ..< components.size) {
			val connector = state.connectors.get(i)
			if (connector != null && connector != components.get(i)) {
				state.connectors.set(i, null)
				remove(connector as Component);
			}
		}
	}

	def private add(Component component) {
		val index = components.indexOf(component)
		if (index >= 0) {
			state.connectors.set(index, component)
			if (component.parent != this) {
				super.addComponent(component)
			}
		}
	}

	def private remove(Component component) {
		if (component?.parent == this) {
			super.removeComponent(component)
		}
	}

	override requestWidgets(int selectedIndex) {
		ensureConnectorsList

		//Ensure that the selected component is added
		if (selectedIndex >= 0) {
			components.get(selectedIndex).add
		}

		switch state.loadMode {
			case CarouselLoadMode::EAGER: {
				components.forEach[add]
			}
			case CarouselLoadMode::SMART: {
				val notAdded = [!state.connectors.contains(it)]
				components.findFirst(notAdded).add
				components.findLast(notAdded).add
			}
		}
	}

	override beforeClientResponse(boolean initial) {
		ensureConnectorsList
		super.beforeClientResponse(initial)
	}

}

interface ComponentSelectListener {
	def void componentSelected(Component component)
}
