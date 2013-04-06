package org.vaadin.virkki.carousel

import com.vaadin.ui.AbstractComponentContainer
import com.vaadin.ui.Component
import java.util.List
import org.vaadin.virkki.carousel.client.widget.CarouselClientScrollRpc
import org.vaadin.virkki.carousel.client.widget.CarouselClientScrollToRpc
import org.vaadin.virkki.carousel.client.widget.CarouselServerRpc
import org.vaadin.virkki.carousel.client.widget.CarouselState
import org.vaadin.virkki.carousel.client.widget.gwt.ArrowKeysMode
import org.vaadin.virkki.carousel.client.widget.gwt.CarouselLoadMode
import com.vaadin.server.Sizeable

abstract class AbstractCarousel extends AbstractComponentContainer implements CarouselServerRpc {

	List<Component> components = newArrayList
	List<ComponentSelectListener> listeners = newArrayList
	var Component selectedComponent

	new() {
		registerRpc(this)
		setHeight(300.0f,Sizeable$Unit::PIXELS)
		setWidth(300.0f,Sizeable$Unit::PIXELS)
	}

	override protected CarouselState getState() {
		super.getState() as CarouselState
	}

	override getComponentCount() {
		addedComponents.size
	}

	override addComponent(Component c) {
		components.add(c)
		ensureConnectorsList
	}

	override removeComponent(Component c) {
		components.remove(c)
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
		state.connectors.filter(typeof(Component))
	}

	def scroll(int change) {
		getRpcProxy(typeof(CarouselClientScrollRpc)).scroll(change)
	}

	def scrollTo(Component component) {
		val index = components.indexOf(component)
		if (index > -1) {
			getRpcProxy(typeof(CarouselClientScrollToRpc)).scrollTo(index)
		}
	}

	def setLoadMode(CarouselLoadMode loadMode) {
		state.loadMode = loadMode
	}

	def getLoadMode() {
		state.loadMode
	}

	def setMouseDragEnabled(boolean enabled) {
		state.mouseDragEnabled = enabled
	}

	def isMouseDragEnabled() {
		state.mouseDragEnabled
	}

	def setTouchDragEnabled(boolean enabled) {
		state.touchDragEnabled = enabled
	}

	def isTouchDragEnabled() {
		state.touchDragEnabled
	}

	def setArrowKeysMode(ArrowKeysMode arrowKeysMode) {
		state.arrowKeysMode = arrowKeysMode
	}

	def getArrowKeysMode() {
		state.arrowKeysMode
	}

	def setMouseWheelEnabled(boolean enabled) {
		state.mouseWheelEnabled = enabled
	}

	def isMouseWheelEnabled() {
		state.mouseWheelEnabled
	}

	def setButtonsVisible(boolean visible) {
		state.buttonsVisible = visible
	}

	def isButtonsVisible() {
		state.buttonsVisible
	}

	def setTransitionDuration(int durationInMilliseconds) {
		state.transitionDuration = durationInMilliseconds
	}

	def getTransitionDuration() {
		state.transitionDuration
	}

	def addComponentSelectListener(ComponentSelectListener listener) {
		listeners.add(listener)
	}

	def removeComponentSelectListener(ComponentSelectListener listener) {
		listeners.remove(listener)
	}

	override widgetSelected(int selectedIndex) {
		if (selectedIndex >= 0 && selectedIndex < components.size) {
			val selected = components.get(selectedIndex)
			if (selected != selectedComponent){
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
			state.connectors.remove(state.connectors.last)
		}

		//Ensure connectors list contains no anomalies
		for (i : 0 ..< components.size) {
			if (state.connectors.get(i) != null && state.connectors.get(i) != components.get(i)) {
				state.connectors.set(i, null)
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

	override requestWidgets(int selectedIndex) {
		ensureConnectorsList

		//Ensure that the selected component is added
		if (selectedIndex >= 0 && state.connectors.get(selectedIndex) == null) {
			add(components.get(selectedIndex))
		}

		switch state.loadMode {
			case CarouselLoadMode::EAGER: {
				components.forEach[add]
			}
			case CarouselLoadMode::SMART: {
				val notAdded = [!state.connectors.contains(it)]
				components.findFirst(notAdded) => [add]
				components.findLast(notAdded) => [add]
			}
		}
	}

	override beforeClientResponse(boolean initial) {

		//TODO: Re-enable
		//					if (initial){
		//						requestWidgets(0)	
		//					}
		//TODO: Remove
		ensureConnectorsList
		super.beforeClientResponse(initial)
	}

}

interface ComponentSelectListener {
	def void componentSelected(Component component)
}
