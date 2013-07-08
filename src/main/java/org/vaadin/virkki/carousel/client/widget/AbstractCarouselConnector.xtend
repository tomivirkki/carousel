package org.vaadin.virkki.carousel.client.widget

import com.vaadin.client.BrowserInfo
import com.vaadin.client.ComponentConnector
import com.vaadin.client.ConnectorHierarchyChangeEvent
import com.vaadin.client.communication.RpcProxy
import com.vaadin.client.communication.StateChangeEvent
import com.vaadin.client.ui.AbstractComponentContainerConnector
import com.vaadin.client.ui.layout.ElementResizeListener
import com.vaadin.shared.communication.ClientRpc
import com.vaadin.shared.communication.ServerRpc
import org.vaadin.virkki.carousel.client.widget.gwt.CarouselWidgetListener
import org.vaadin.virkki.carousel.client.widget.gwt.DraggableCarouselWidget

@SuppressWarnings("serial")
abstract class AbstractCarouselConnector extends AbstractComponentContainerConnector {
	val protected rpc = RpcProxy::create(CarouselServerRpc, this)

	val ElementResizeListener listener = [
		widget.setCarouselSize(layoutManager.getInnerWidth(element), layoutManager.getInnerHeight(element))
	]

	override init() {
		super.init
		layoutManager.addElementResizeListener(widget.element, listener)
		CarouselClientScrollRpc.registerRpc[widget.scroll(it)]
		CarouselClientScrollToRpc.registerRpc[widget.scrollTo(it)]
	}

	override CarouselState getState() {
		super.getState() as CarouselState
	}

	override DraggableCarouselWidget getWidget() {
		super.widget as DraggableCarouselWidget
	}

	override onStateChanged(StateChangeEvent stateChangeEvent) {
		super.onStateChanged(stateChangeEvent)
		widget.loadMode = state.loadMode
		widget.widgets = state.connectors.map[(it as ComponentConnector)?.widget]
		widget.arrowKeysMode = state.arrowKeysMode
		widget.mouseDragEnabled = state.mouseDragEnabled
		widget.touchDragEnabled = state.touchDragEnabled
		widget.mouseWheelEnabled = state.mouseWheelEnabled
		widget.buttonsVisible = state.buttonsVisible
		widget.transitionDuration = state.transitionDuration
		widget.swipeSensitivity = state.swipeSensitivity
		widget.animationFallback = BrowserInfo::get.IE8 || BrowserInfo::get.IE9
	}

	override updateCaption(ComponentConnector connector) {
	}

	override onConnectorHierarchyChange(ConnectorHierarchyChangeEvent connectorHierarchyChangeEvent) {
	}

}

interface CarouselServerRpc extends CarouselWidgetListener, ServerRpc {
}

interface CarouselClientScrollRpc extends ClientRpc {
	def void scroll(int change)
}

interface CarouselClientScrollToRpc extends ClientRpc {
	def void scrollTo(int componentIndex)
}
